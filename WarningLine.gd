extends LineEdit

var blink_the_message = false # To know, when to perform the blinking.
var time_left = .0 # To know, when to reset the time.

const BLINK_TIME = 4.0 # For how long to blink.
const BLINK_SPEED = 2.0 # How quickly to blink.

func _on_WarningLine_text_changed(new_text):
	blink_the_message = true
	time_left = BLINK_TIME

func reset():
	blink_the_message = false
	time_left = BLINK_TIME

func _process(delta):
	if blink_the_message:
		time_left -= delta
		self.self_modulate.a = 1.0 - max(sin((time_left) * PI * BLINK_SPEED), .0)
		if time_left < .0:
			reset()
