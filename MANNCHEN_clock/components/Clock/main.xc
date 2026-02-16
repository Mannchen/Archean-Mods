#DATAPORT input "data" 0 "Time (s)"

#INFO checkbox "realtime" 0 "show real time"
#INFO drag "offset" 0 -11 11 1 "Hour offset"

include "unix_datetime.xc"

const $hand_speed = 10000
var $d_time:number

init
	set_emissive("Body", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("HourHand", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("MinuteHand", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("SecondHand", "Emissive", color(160, 255, 0), 0.02)


input.0 ($time:number)
	$d_time = $time


tick
	var $time = 0
	var $i_offset = get_info("offset")
	
	if get_info("realtime")
		$time = @unix_to_datetime(floor(time + $i_offset*3600)).day_seconds:number
	else
		$time = $d_time + $i_offset*3600
	
	animate("SecondJoint", angular_z, $hand_speed, ($time % 60) * -6) 
	animate("MinuteJoint", angular_z, $hand_speed, (($time / 60) % 60) * -6)
	animate("HourJoint", angular_z, $hand_speed, (($time / 3600) % 12) * -30)
