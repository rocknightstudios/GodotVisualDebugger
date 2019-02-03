extends Camera2D

onready var is_zoom_lerping = false # Whether the zooming to the new zoom state should be performed.
onready var is_camera_being_centered_around_mouse_cursor = false # To perform centering, only, when it is required.
onready var camera_tab = get_parent().get_node("TabContainer/Camera") # For speed and convenience.
onready var zoom_indicator_x = camera_tab.get_node("ZoomIndicatorX") # For speed and convenience.
onready var zoom_indicator_y = camera_tab.get_node("ZoomIndicatorY") # For speed and convenience.
onready var mouse_position_wrapper = camera_tab.get_node("MousePosition") # For speed and convenience.

var previous_mouse_drag_position = Vector2(.0, .0) # To calculate, where to move.
var new_zoom_value = Vector2(.0, .0) # For speed and convenience. Lerp to this zoom.
var new_zoom_position = Vector2(.0, .0) # For speed and convenience. Lerp to this zoom.
var zoom_lerp_progress = .0 # To ensure tight lerping and speed.
var lerp_to_center_progress = .0 # To have a tight control over lerping.
var mouse_center_position = Vector2(.0, .0) # Where to lerp, when screen has to be centered around the mouse.
var has_lerped_to_center = false # To know, when to stop lerping and just follow.
var just_from_process = false # To detect only the first input event. Basically sync _input with _process.
var move_distance = Vector2(.0, .0) # To pass calculated mouse relative position change.

const ZOOM_OVER_ONE_COEFFICIENT = .08 # How smoothly to change zoom value, when zoom is over 1.0.
const UNDER_ONE_ZOOM_BAR_COLOR = Color(.3, .7, 1.0, 1.0) # To avoid having magic numbers.
const OVER_ONE_ZOOM_BAR_COLOR = Color(1.0, 1.0, .0, 1.0) # To avoid having magic numbers.
const LERP_TO_CENTER_SPEED = 2.0 # How quickly to lerp center around mouse cursor.
const ZOOM_COEFFICIENT = .01 # How relatively quickly to zoom in and out.
const ZOOM_SHIFT_COEFFICIENT = .1 # If shift key is pressed zooming should happen much faster.
const ZOOM_BOUNDS = Vector2(.00001, 1500.0) # Don't let the zoom to become larger or smaller than the bounds.
const ZOOM_LERP_SPEED = 2.0 # To avoid magic numbers. How is the zoom lerping.
const MOUSE_RELATIVE_STEP_SMOOTH_COEFFICIENT = .25 # How much to smooth out the mouse relative vector.

func _input(event):
	if just_from_process:
		if event is InputEventMouseMotion:
			move_distance = move_distance.linear_interpolate(event.relative, MOUSE_RELATIVE_STEP_SMOOTH_COEFFICIENT)
		just_from_process = false
	if Input.is_key_pressed(KEY_CONTROL):
		manage_scene_zoom(event)
	if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
		manage_mouse_drag()
	else:
		previous_mouse_drag_position = get_viewport().get_mouse_position()

func manage_mouse_zoom_state(direction):
	var zoom_step = (ZOOM_SHIFT_COEFFICIENT if Input.is_key_pressed(KEY_SHIFT) else ZOOM_COEFFICIENT) \
					* direction # For speed and convenience.
	var previous_zoom = zoom # To calculate the relative zoom change.
	zoom = Vector2(clamp(zoom.x + zoom_step * zoom.x, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y), \
				   clamp(zoom.y + zoom_step * zoom.y, ZOOM_BOUNDS.x, ZOOM_BOUNDS.y))
	var half_viewport_size = get_viewport().size * .5 # For speed and convenience.
	half_viewport_size = half_viewport_size + get_viewport().get_mouse_position() - half_viewport_size
	position += Vector2(half_viewport_size.x * (previous_zoom.x - zoom.x), half_viewport_size.y * (previous_zoom.y - zoom.y))
	manage_zoom_display()

func manage_mouse_drag():
	var mouse_drag_position = get_viewport().get_mouse_position() # For speed and convenience.
	var distance_to_previous_mouse_position = mouse_drag_position.distance_to(previous_mouse_drag_position) # For speed and convenience.
	if distance_to_previous_mouse_position > VDGlobal.APPROXIMATION_FLOAT:
		VDGlobal.visual_debugger.is_moving_to_node = false
		position.x += (previous_mouse_drag_position.x - mouse_drag_position.x) * zoom.x
		position.y += (previous_mouse_drag_position.y - mouse_drag_position.y) * zoom.y
	previous_mouse_drag_position = get_viewport().get_mouse_position()

func manage_scene_zoom(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			manage_mouse_zoom_state(-1.0)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			manage_mouse_zoom_state(1.0)

func manage_zoom_display():
	var zoom_range = ZOOM_BOUNDS.y - ZOOM_BOUNDS.x # For speed and convenience.

	var current_test_zoom = 1.0 # Tmp value to check, when the bound is reached for both max and current value.
	var current_step = 0 # How many steps wide is the current and max value.

	while current_test_zoom < zoom_range:
		current_test_zoom = current_test_zoom + ZOOM_COEFFICIENT * current_test_zoom
		current_step += 1
	zoom_indicator_x.get_child(0).get_child(1).max_value = current_step
	current_test_zoom = 1.0
	current_step = 0
	while current_test_zoom < zoom.x:
		current_test_zoom = current_test_zoom + ZOOM_COEFFICIENT * current_test_zoom
		current_step += 1
	zoom_indicator_x.get_child(0).get_child(1).step = 1
	zoom_indicator_x.get_child(0).get_child(1).value = current_step

	while current_test_zoom < zoom_range:
		current_test_zoom = current_test_zoom + ZOOM_COEFFICIENT * current_test_zoom
		current_step += 1
	zoom_indicator_y.get_child(0).get_child(1).max_value = current_step
	current_test_zoom = 1.0
	current_step = 0
	while current_test_zoom < zoom.y:
		current_test_zoom = current_test_zoom + ZOOM_COEFFICIENT * current_test_zoom
		current_step += 1
	zoom_indicator_y.get_child(0).get_child(1).step = 1
	zoom_indicator_y.get_child(0).get_child(1).value = current_step

	if zoom.x < 1.0:
		zoom_indicator_x.get_child(1).get_child(2).max_value = 1.0
		zoom_indicator_x.get_child(1).get_child(2).modulate = UNDER_ONE_ZOOM_BAR_COLOR
		zoom_indicator_x.get_child(1).get_child(1).modulate = UNDER_ONE_ZOOM_BAR_COLOR
	else:
		zoom_indicator_x.get_child(1).get_child(2).max_value = (zoom_range - 1.0) * ZOOM_OVER_ONE_COEFFICIENT
		zoom_indicator_x.get_child(1).get_child(2).modulate = OVER_ONE_ZOOM_BAR_COLOR
		zoom_indicator_x.get_child(1).get_child(1).modulate = OVER_ONE_ZOOM_BAR_COLOR
	zoom_indicator_x.get_child(1).get_child(2).step = 1
	zoom_indicator_x.get_child(1).get_child(2).value = zoom.x
	zoom_indicator_x.get_child(1).get_child(1).text = str(zoom.x)

	if zoom.y < 1.0:
		zoom_indicator_y.get_child(1).get_child(2).max_value = 1.0
		zoom_indicator_y.get_child(1).get_child(2).modulate = UNDER_ONE_ZOOM_BAR_COLOR
		zoom_indicator_y.get_child(1).get_child(1).modulate = UNDER_ONE_ZOOM_BAR_COLOR
	else:
		zoom_indicator_y.get_child(1).get_child(2).max_value = (zoom_range - 1.0) * ZOOM_OVER_ONE_COEFFICIENT
		zoom_indicator_y.get_child(1).get_child(2).modulate = OVER_ONE_ZOOM_BAR_COLOR
		zoom_indicator_y.get_child(1).get_child(1).modulate = OVER_ONE_ZOOM_BAR_COLOR
	zoom_indicator_y.get_child(1).get_child(2).step = 1
	zoom_indicator_y.get_child(1).get_child(2).value = zoom.y
	zoom_indicator_y.get_child(1).get_child(1).text = str(zoom.y)

func _process(delta):
	var viewport_mouse_position = get_viewport().get_mouse_position() # For speed and convenience.
	mouse_position_wrapper.get_child(0).get_child(0).text = str(viewport_mouse_position.x, ", ", viewport_mouse_position.y)
	mouse_position_wrapper.get_child(1).get_child(0).text = str(position.x + viewport_mouse_position.x * zoom.x,\
																", ", position.y + viewport_mouse_position.y * zoom.y)

	just_from_process = true
	if is_zoom_lerping:
		lerp_zoom(delta)
	elif is_camera_being_centered_around_mouse_cursor:
		lerp_to_center_around_mouse_cursor(delta)
		if !Input.is_key_pressed(KEY_F11):
			is_camera_being_centered_around_mouse_cursor = false
	elif Input.is_key_pressed(KEY_F11):
		set_to_center_around_mouse_cursor()
	else:
		has_lerped_to_center = false

# Centering around mouse cursor must always use the defeault get_viewport size, that's set in the window settings.
# If test values in settings are set for window size they are going to be used instead of default ones
# which may cause weird glitches if 2D stretching is used. Viewport stretch mode should still work fine.
# So it is better to set test values to 0, 0.
# Also for mouse wrapping it is necessary to use OS.window_size, instead of get_viewport().size, to take into acount
# actual window size changes including the black borders that appear if aspect ratio is set to be kept.
onready var original_half_viewport_size = get_viewport().size * .5 # The default middle of the screen for centering around mouse cursor.

func set_to_center_around_mouse_cursor():
	if !has_lerped_to_center:
		lerp_to_center_progress = .0
	mouse_center_position = position + (get_viewport().get_mouse_position() - original_half_viewport_size) * zoom
	Input.warp_mouse_position(OS.window_size * .5)
	is_camera_being_centered_around_mouse_cursor = true

func lerp_to_center_around_mouse_cursor(delta):
	if lerp_to_center_progress > 1.0 - VDGlobal.APPROXIMATION_FLOAT:
		Input.warp_mouse_position(OS.window_size * .5)
		position += move_distance * zoom
		has_lerped_to_center = true
	else:
		lerp_to_center_progress = min(lerp_to_center_progress + delta * LERP_TO_CENTER_SPEED, 1.0)
		position = Vector2(lerp(position.x, mouse_center_position.x, lerp_to_center_progress), \
						   lerp(position.y, mouse_center_position.y, lerp_to_center_progress))
		move_distance = Vector2(.0, .0)

func lerp_zoom(delta):
	zoom_lerp_progress += delta * ZOOM_LERP_SPEED
	var previous_position = position # To calculate coefficient for synced zoom.
	position = Vector2(lerp(position.x, new_zoom_position.x, zoom_lerp_progress), \
					   lerp(position.y, new_zoom_position.y, zoom_lerp_progress))
	if (1.0 - abs(position.x) / max(abs(previous_position.x), VDGlobal.APPROXIMATION_FLOAT)) < 1.0 - VDGlobal.APPROXIMATION_FLOAT:
		zoom = Vector2(lerp(zoom.x, new_zoom_value.x, 1.0 - abs(position.x) / max(abs(previous_position.x), VDGlobal.APPROXIMATION_FLOAT)), \
					   lerp(zoom.y, new_zoom_value.y, 1.0 - abs(position.y) / max(abs(previous_position.y), VDGlobal.APPROXIMATION_FLOAT)))
	else:
		zoom = zoom.linear_interpolate(new_zoom_value, zoom_lerp_progress)
	if zoom_lerp_progress > 1.0:
		zoom = new_zoom_value
		position = new_zoom_position
		is_zoom_lerping = false
	manage_zoom_display()

func set_zoom_to():
	var zoom_to = camera_tab.get_node("ZoomTo") # For speed and convenience.
	var zoom_value = zoom_to.get_child(0) # For speed and convenience.
	var zoom_position = zoom_to.get_child(1) # For speed and convenience.
	is_zoom_lerping = true
	zoom_lerp_progress = .0
	new_zoom_value = Vector2(Vector2(clamp(float(zoom_value.get_child(0).text), ZOOM_BOUNDS.x, ZOOM_BOUNDS.y), \
									 clamp(float(zoom_value.get_child(1).text), ZOOM_BOUNDS.x, ZOOM_BOUNDS.y)))
	new_zoom_position = Vector2(Vector2(float(zoom_position.get_child(0).text), float(zoom_position.get_child(1).text)))
