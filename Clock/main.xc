#DATAPORT input "data" 0 "Time (s)"

#INFO checkbox "realtime" 0 "show real time"
#INFO drag "offset" 0 -11 11 1 "Hour offset"

include "unix_datetime.xc"

const $hand_speed = 10

const $max_rotation = 0.5 - 1/360

var $d_time:number
var $prev_time:number

var $current_value_hour:number
var $current_pos_hour:number
var $current_value_minute:number
var $current_pos_minute:number
var $current_value_second:number
var $current_pos_second:number

var $g_delta:number

init
	set_emissive("Body", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("HourHand", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("MinuteHand", "Emissive", color(160, 255, 0), 0.02)
	set_emissive("SecondHand", "Emissive", color(160, 255, 0), 0.02)


input.0 ($time:number)
	$d_time = $time


function @sign($value:number) :number
	return if($value < 0, -1, 1)


; predict where $value has moved to
function @predict_speed ($target:number, $value:number, $speed:number) :number
	return min(max($value - $g_delta*$speed, $target), $value + $g_delta*$speed)


; makes sure $current is not more than $max_diff away from $target
function @clamp_difference($target:number, $current:number, $max_diff:number) :number
	return min(max($target - $max_diff, $current), $target + $max_diff)


; get target angle for value
function @target_directional ($value:number, $current_value:number, $value_360:number) :number
	return (1-(($value % $value_360) / $value_360))* 360


; custom animation that always rotates in the same direction
function @animate_directional ($joint:text, $axis:number, $speed:number, $current:number, $target:number) :number
	$target = $target % 360
	if $target < 0 
		$target += 360
	$current = $current % 360
	if $current < 0
		$current += 360
	
	if @sign($speed) != sign($target-$current)
		$target += @sign($speed)*360
	
	var $movement = $target-$current
	if $movement < 0
		$movement = max($movement, $speed*$g_delta*360)
	else
		$movement = min($movement, $speed*$g_delta*360)
	
	var $new_pos = $current + $movement
	if $new_pos < 0
		$new_pos += 360
	if $new_pos >= 360
		$new_pos -= 360

	animate($joint, $axis, 1000000, $new_pos)
	return $new_pos


tick
	$g_delta = time - $prev_time
	var $time = 0

	var $i_offset = get_info("offset")
	
	if get_info("realtime")
		$time = @unix_to_datetime(floor(time + get_info("offset")*3600)).day_seconds:number
	else
		$time = $d_time + $i_offset*3600
	
	$current_value_second = @predict_speed($time, $current_value_second, 60*$hand_speed)
	$current_value_second = @clamp_difference($time, $current_value_second, 120)
	$current_pos_second = @animate_directional("SecondJoint", angular_z, @sign($time-$current_value_second)*$hand_speed, $current_pos_second, @target_directional($time, $current_value_second, 60))

	var $minutes = $time / 60
	$current_value_minute = @predict_speed($minutes, $current_value_minute, 60*$hand_speed)
	$current_value_minute = @clamp_difference($minutes, $current_value_minute, 120)
	$current_pos_minute = @animate_directional("MinuteJoint", angular_z, @sign($minutes-$current_value_minute)*$hand_speed, $current_pos_minute, @target_directional($minutes, $current_value_minute, 60))

	var $hours = $minutes / 60
	$current_value_hour = @predict_speed($hours, $current_value_hour, 12*$hand_speed)
	$current_value_hour = @clamp_difference($hours, $current_value_hour, 24)
	$current_pos_hour = @animate_directional("HourJoint", angular_z, @sign($hours-$current_value_hour)*$hand_speed, $current_pos_hour, @target_directional($hours, $current_value_hour, 12))

