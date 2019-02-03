extends Node

const FULL_CIRCLE_IN_DEGREES = 360.0 # To avoid having magic numbers.
const TO_SECONDS_MULTIPLIER = 1000 # To avoid having magic numbers.
const APPROXIMATION_FLOAT = .000001 # To avoid having magic numbers.
const NORMALIZED_UPPER_BOUND = 1.0 - APPROXIMATION_FLOAT # For speed and convenience.
const POSITIVEINFINITY = 3.402823e+38 # For convenience.
const NEGATIVEINFINITY = -2.802597e-45 # For convenience.
const Z_INDEX_OVER_MENU = 666 # To avoid having magic numbers.
const CANVAS_LAYER_ID = 127 # To avoid having magic numbers.

var visual_debugger_scene = preload("res://VisualDebugger/VisualDebugger.tscn") # To have persistent visual game debugger.
var visual_debugger = null # Instanced visual debugger.

onready var visual_debugger_z_index_node2D = Node2D.new() # To be able to set the z_index.
onready var cached_root = get_tree().get_root() # For speed and convenience.

func _ready():
	visual_debugger = visual_debugger_scene.instance()
	add_child(visual_debugger_z_index_node2D)
	visual_debugger_z_index_node2D.name = "VisualDebuggerZIndex"
	visual_debugger_z_index_node2D.z_index = Z_INDEX_OVER_MENU
	visual_debugger.layer = CANVAS_LAYER_ID
	visual_debugger_z_index_node2D.add_child(visual_debugger)

func lerp_array(from_array, to_array, speed):
	for i in range(0, from_array.size()):
		from_array[i] = lerp(from_array[i], to_array[i], speed)
	return from_array
