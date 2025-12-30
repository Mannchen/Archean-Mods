#DATAPORT input "data" 0 "On"
#DATAPORT input "data" 1 "Light"
#DATAPORT input "data" 2 "Rotation speed"

#INFO drag "rotationSpeed" 12 -60 60 1 "Rotation speed"
#INFO drag "maxPower" 50 1 1000 50 "Max. Power"
#INFO slider "angle" 100 10 160  "Angle"
#INFO colorpicker "color" "Light Color"
#INFO checkbox "datacolor" 0 "Take color from input"

var $g_on :number
var $g_rotation_speed = 1
var $g_light_intensity = 1
var $g_light_color :number


input.0 ($on :number, $light :text, $speed :text)
	$g_on = $on

	if $light != "" and isnumeric($light)
		if get_info("datacolor")
			$g_light_intensity = color_a($light) / 255
			$g_light_color = color(color_r($light), color_g($light), color_b($light))
		else
			$g_light_intensity = clamp($light, 0, 1)
	
	if $speed != "" and isnumeric($speed)
		$g_rotation_speed = $speed
	
	$light = ""
	$speed = ""


tick
	var $color = 0
	if get_info("datacolor")
		$color = $g_light_color
	else
		$color = get_info("color")

	var $light_angle = get_info("angle")

	if $g_on
		var $speed = get_info("rotationSpeed") * $g_rotation_speed

		var $current_power = $g_light_intensity * get_info("maxPower")
		$current_power = pull_power("lv", 30, $current_power)
		$current_power /= 2

		set_emissive("LightAssembly", "LED", $color, $current_power)
		set_emissive("LightAssembly", "ChromeEmissive", $color, $current_power / 100)
		set_light("LightX", 0.03, $color, $current_power, $light_angle) 
		set_light("LightMX", 0.03, $color, $current_power, $light_angle) 

		animate("Rotator", angular_z, $speed*6)
	else
		set_emissive("LightAssembly", "LED", $color, 0)
		set_emissive("LightAssembly", "ChromeEmissive", $color, 0)
		set_light("LightX", 0, 0, 0, $light_angle) 
		set_light("LightMX", 0, 0, 0, $light_angle) 

		animate("Rotator", angular_z, 0)

