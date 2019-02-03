extends CanvasLayer

onready var debugger_camera = $"DebuggerCamera2D" # For speed and convenience.
onready var camera_movement_speed_slider = $"GeneralControlsContainer/CameraMovementSpeedSlider" # For speed and convenience.
onready var scene_node_selector = $"SceneNodeSelector" # For speed and convenience.
onready var enable_exact_follow = $"GeneralControlsContainer/EnableExactFollow" # For speed and convenience.
onready var warning_line = $"InfoContainer/WarningLine" # For speed and convenience.
onready var is_moving_to_node = false # To disable moving to node, when it is reached.
onready var camera_move_lerp_speed = 5.0 # How quickly to move the camera.
onready var relative_position = Vector2(.0, .0) # To calculate correct position, where to move to each node.
onready var visual_debugger_background = $"VisualDebuggerBackground" # For speed and convenience.
onready var original_visual_debugger_background_modulate = visual_debugger_background.modulate # To know, where to reset the value.
onready var mouse_over_visual_debugger_background_modulate = Color(original_visual_debugger_background_modulate.r + VISUAL_BACKGROUND_MODULATE_B_DELTA, original_visual_debugger_background_modulate.g + VISUAL_BACKGROUND_MODULATE_B_DELTA, original_visual_debugger_background_modulate.b + VISUAL_BACKGROUND_MODULATE_B_DELTA, original_visual_debugger_background_modulate.a + VISUAL_BACKGROUND_MODULATE_B_DELTA) # When mouse is over visual debugger change the background color.

var mouse_over_tint_lerp_progress = .0 # To have a tight control over lerping and save resources.
var menu_is_active = false # To avoid reactivating menu.
var transformation_mode = VD_Transformation_modes.MOVE # For speed and convenience.
var node_is_selected = false # To save resources and know, when some node is selected in the scene.
var visual_debugger_children = [] # To not loose the access to the children.
var visual_debugger_is_active = false # To switch between enabled and disabled.
var mouse_is_over_visual_debugger_gui = false # To know, when it is allowed to perform scene node detection.
var slide_direction = VD_Slide_direction.NONE # To know, when to slide in and out the menu.
var keyboard_movement_is_allowed = true # For the access from other behaviours.
var forbid_selection_circle_management = false # To not manage selection circle, when transformation is active.
var full_selected_path = "" # To have a convenient access from other scripts.
var game_camera = null # To know, to which camera to reset back.
var outliner = null # To detect and manage scene tree changes.
var is_game_camera = false # To have a consistent warning, that game camera has dissapeared.

const BACKGROUND_COLOR_LERP_SPEED = 3.0 # How quickly to fade to the new state.
const VISUAL_BACKGROUND_MODULATE_B_DELTA = .25 # To avoid having magic numbers.
const MENU_SLIDE_POS_BOUNDS = Vector2(-500.0, 0.0) # Where to slide menu on x.
const SLIDE_SPEED = 5.0 # How quickly to slide in and out.

enum VD_Slide_direction {NONE, IN, OUT}
enum VD_Transformation_modes {MOVE, ROTATE, SCALE}

func _ready():
	set_gui_visibility(false)
	self.offset.x = MENU_SLIDE_POS_BOUNDS.x
	for i in range(1, self.get_child_count()):
		visual_debugger_children.append(self.get_child(i))
	deactivate_menu()

func set_gui_visibility(state):
	if state:
		slide_direction = VD_Slide_direction.IN
	else:
		slide_direction = VD_Slide_direction.OUT

func activate_menu():
	menu_is_active = true
	for i in range(0, visual_debugger_children.size()):
		add_child(visual_debugger_children[i])

func deactivate_menu():
	menu_is_active = false
	for i in range(0, visual_debugger_children.size()):
		remove_child(visual_debugger_children[i])

func slide_menu(goal_pos, delta):
	if abs(abs(self.offset.x) - abs(goal_pos)) > VDGlobal.APPROXIMATION_FLOAT:
		self.offset.x = lerp(self.offset.x, goal_pos, delta * SLIDE_SPEED)
	else:
		slide_direction = VD_Slide_direction.NONE

func manage_camera_movement(speed):
	var direction = Vector2(.0, .0) # The direction of the current movement step.
	if Input.is_key_pressed (KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed (KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed (KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed (KEY_DOWN):
		direction.y += 1.0

	debugger_camera.position += direction * speed

	if direction.length() > VDGlobal.APPROXIMATION_FLOAT:
		is_moving_to_node = false

func set_moving_to_node(state, relative_position):
	is_moving_to_node = state
	self.relative_position = relative_position

func move_to_the_node(delta):
	var movement_speed = delta * camera_move_lerp_speed # To save resources.
	var goal_position = relative_position - (get_viewport().size * .5 * debugger_camera.zoom) * scale # For speed and convenience.
	if enable_exact_follow.pressed:
		debugger_camera.position = goal_position
	else:
		debugger_camera.position = Vector2(lerp(debugger_camera.position.x, goal_position.x, movement_speed), lerp(debugger_camera.position.y, goal_position.y, movement_speed))
	if goal_position.distance_to(debugger_camera.position) < VDGlobal.APPROXIMATION_FLOAT:
		is_moving_to_node = false
		debugger_camera.position = goal_position

func _on_disable_keyboard_movement():
	keyboard_movement_is_allowed = false

func _on_enable_keyboard_movement():
	keyboard_movement_is_allowed = true

func set_debugger_camera():
	outliner.form_the_whole_outliner()
	debugger_camera.make_current()
	debugger_camera.position = game_camera.position
	debugger_camera.zoom = game_camera.zoom
	debugger_camera.anchor_mode = game_camera.anchor_mode
	debugger_camera.manage_zoom_display()

func set_game_camera():
	if game_camera == null || !(weakref(game_camera)).get_ref():
		outliner._on_form_the_outliner()
	game_camera.make_current()

func _process(delta):
	if Input.is_action_just_pressed ("visual_debugger"):
		if visual_debugger_is_active:
			visual_debugger_is_active = false
			set_gui_visibility(false)
			set_game_camera()
			get_tree().paused = false
			deactivate_menu()
		else:
			if !menu_is_active:
				activate_menu()
			get_tree().paused = true
			visual_debugger_is_active = true
			set_gui_visibility(true)
			set_debugger_camera()
			visual_debugger_background.modulate = original_visual_debugger_background_modulate
			is_game_camera = true
			Input.set_mouse_mode(0)

	if !(weakref(game_camera)).get_ref():
		visual_debugger_background.modulate = Color(1.0, .0, .0, 1.0)
		is_game_camera = false

	if visual_debugger_is_active:
		if is_game_camera:
			if mouse_is_over_visual_debugger_gui:
				if mouse_over_tint_lerp_progress < VDGlobal.NORMALIZED_UPPER_BOUND:
					mouse_over_tint_lerp_progress = min(mouse_over_tint_lerp_progress + delta * BACKGROUND_COLOR_LERP_SPEED, 1.0)
					var array_lerp_result = VDGlobal.lerp_array([original_visual_debugger_background_modulate.r, original_visual_debugger_background_modulate.g, original_visual_debugger_background_modulate.b, original_visual_debugger_background_modulate.a], [mouse_over_visual_debugger_background_modulate.r, mouse_over_visual_debugger_background_modulate.g, mouse_over_visual_debugger_background_modulate.b, mouse_over_visual_debugger_background_modulate.a], mouse_over_tint_lerp_progress) # For speed and convenience.
					visual_debugger_background.modulate = Color(array_lerp_result[0], array_lerp_result[1], array_lerp_result[2], array_lerp_result[3])
					keyboard_movement_is_allowed = false
					forbid_selection_circle_management = true
			else:
				if mouse_over_tint_lerp_progress > VDGlobal.APPROXIMATION_FLOAT:
					mouse_over_tint_lerp_progress = max(mouse_over_tint_lerp_progress - delta * BACKGROUND_COLOR_LERP_SPEED, .0)
					var array_lerp_result = VDGlobal.lerp_array([original_visual_debugger_background_modulate.r, original_visual_debugger_background_modulate.g, original_visual_debugger_background_modulate.b, original_visual_debugger_background_modulate.a], [mouse_over_visual_debugger_background_modulate.r, mouse_over_visual_debugger_background_modulate.g, mouse_over_visual_debugger_background_modulate.b, mouse_over_visual_debugger_background_modulate.a], mouse_over_tint_lerp_progress) # For speed and convenience.
					visual_debugger_background.modulate = Color(array_lerp_result[0], array_lerp_result[1], array_lerp_result[2], array_lerp_result[3])
					keyboard_movement_is_allowed = true
					forbid_selection_circle_management = false

			if keyboard_movement_is_allowed:
				manage_camera_movement(camera_movement_speed_slider.value)

			if is_moving_to_node:
				move_to_the_node(delta)

	if slide_direction == VD_Slide_direction.IN:
		slide_menu(MENU_SLIDE_POS_BOUNDS.y, delta)
	elif slide_direction == VD_Slide_direction.OUT:
		slide_menu(MENU_SLIDE_POS_BOUNDS.x, delta)

func _on_JumpPositionButton_button_down():
	debugger_camera.position.x = $"GeneralControlsContainer/CameraJumpPositionX".text.to_int()
	debugger_camera.position.y = $"GeneralControlsContainer/CameraJumpPositionY".text.to_int()
