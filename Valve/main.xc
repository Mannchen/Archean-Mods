#DATAPORT "data" input.0 "I/O Input"
#DATAPORT "data" output.0 "Open"

#INFO drag "style" 0 0 1 1 "Valve Style"
#INFO checkbox "input" 0 "I/O Input"

var $pressed = 0

storage var $open :number
var $style = 0


function @animate_valve($instant: number)
	var $pos_open = if($style == 1, 350, 0)
	var $pos_closed = if($style == 1, -360, -90)
	var $lin_open = if($style == 1, 0.01, 0)
	var $lin_closed = 0

	animate("joint", angular_z, if($instant, 10000, abs($pos_closed - $pos_open)*2), if($open, $pos_open, $pos_closed))
	animate("joint", linear_z, if($instant, 10000, abs($lin_closed - $lin_open)*2), if($open, $lin_open, $lin_closed))


click($x :number, $y: number, $mat :text)
	if $pressed == 0
		$pressed = 2
		$open = !$open
		@animate_valve(0)

input.0 ($io_input :number)
	$io_input = if($io_input, 1, 0)
	if $open != $io_input and get_info("input") == 1
		$open = $io_input
		@animate_valve(0)


init
	toggle_renderable("ValveHandle", $style == 0)
	toggle_renderable("ValveKnob", $style == 1)
	@animate_valve(1)

tick
	if $pressed > 0
		$pressed -= 1
	if $style != get_info("style")
		$style = get_info("style")
		toggle_renderable("Handle", $style == 0)
		toggle_renderable("Knob", $style == 1)
		@animate_valve(1)
	output.0($open)
