#DATAPORT input  "data" 0 "Lock"
#DATAPORT output "data" 0 "Open"
#DATAPORT output "data" 1 "Locked"
#DATAPORT output "data" 2 "Pushed"

#INFO slider "open_angle" 90 0 180 "Open angle"


storage var $g_open :number
storage var $g_locked :number

var $g_pushed = 0

var $g_state_door_open :number
var $g_state_door_locked :number

var $g_fail_open :number
var $g_anim_fail_open :number

var $g_anim_open :number
var $g_anim_locked :number

const $c_door_swing_time = 1.5
var $c_door_swing_ticks :number
const $c_lever_turn_time = 0.3
var $c_lever_turn_ticks :number
const $c_lock_time = 1.0
var $c_lock_ticks :number


init
	$c_door_swing_ticks = ceil(system_frequency * $c_door_swing_time)
	$c_lever_turn_ticks = ceil(system_frequency * $c_lever_turn_time)
	$c_lock_ticks = ceil(system_frequency * $c_lock_time)

	$g_state_door_open = $g_open
	$g_state_door_locked = $g_locked


input.0 ($lock :number)
	if !($g_open or $g_state_door_open)
		$g_locked = $lock


click ($x :number, $y:number, $material: text)

	if $material == "turnhandle" and !($g_open or $g_state_door_open)
		$g_locked = !$g_locked
		return

	if $material != "frame"
		$g_pushed = 1
		if !$g_locked
			$g_open = !$g_open
		else
			$g_fail_open = 1


tick
	if $g_open
		if !$g_state_door_open
			; open door
			if $g_anim_open < $c_lever_turn_ticks
				animate("JointLever", angular_y, 90/$c_lever_turn_time, -90)
			elseif $g_anim_open < $c_lever_turn_ticks + $c_door_swing_ticks
				var $open_angle = get_info("open_angle")
				animate("JointHinge", angular_z, $open_angle / $c_door_swing_time, -$open_angle)
			elseif $g_anim_open >= $c_lever_turn_ticks + $c_door_swing_ticks
				$g_state_door_open = 1
				$g_anim_open = -1
			$g_anim_open += 1

		elseif $g_anim_open > 0 ; reverse close
			$g_state_door_open = 0
			$g_anim_open = $c_lever_turn_ticks + $c_door_swing_ticks - $g_anim_open

	else
		if $g_state_door_open
			; close door
			if $g_anim_open < $c_door_swing_ticks
				animate("JointHinge", angular_z, get_info("open_angle")/$c_door_swing_time, 0)
			elseif $g_anim_open <= $c_door_swing_ticks + $c_lever_turn_ticks
				animate("JointLever", angular_y, 90/$c_lever_turn_time, 0)
			elseif $g_anim_open >= $c_door_swing_ticks + $c_lever_turn_ticks
				$g_state_door_open = 0
				$g_anim_open = -1
			$g_anim_open += 1

		elseif $g_anim_open > 0
			$g_state_door_open = 1
			$g_anim_open = $c_door_swing_ticks + $c_lever_turn_ticks - $g_anim_open


	if $g_locked
		if !$g_state_door_locked
			; lock
			if $g_anim_locked < $c_lock_ticks
				animate("JointTurnhandle", angular_y, 640/$c_lock_time, 270)
			elseif $g_anim_locked >= $c_lock_ticks
				$g_state_door_locked = 1
				$g_anim_locked = -1
			$g_anim_locked += 1

		elseif $g_anim_locked > 0
			$g_state_door_locked = 0
			$g_anim_locked = $c_lock_ticks - $g_anim_locked

	else
		if $g_state_door_locked
			; unlock
			if $g_anim_locked < $c_lock_ticks
				animate("JointTurnhandle", angular_y, 640/$c_lock_time, -270)
			elseif $g_anim_locked >= $c_lock_ticks
				$g_state_door_locked = 0
				$g_anim_locked = -1
			$g_anim_locked += 1

		elseif $g_anim_locked > 0
			$g_state_door_locked = 1
			$g_anim_locked = $c_lock_ticks - $g_anim_locked


	if $g_anim_fail_open > 0
		if $g_anim_fail_open < $c_lever_turn_ticks
			animate("JointLever", angular_y, 90/$c_lever_turn_time, -90)
		elseif $g_anim_fail_open < $c_lever_turn_ticks*2
			animate("JointLever", angular_y, 90/$c_lever_turn_time, 0)
		elseif $g_anim_fail_open >= $c_lever_turn_ticks*2
			$g_anim_fail_open = -1
		$g_anim_fail_open += 1

	if $g_fail_open
		$g_fail_open = 0
		if $g_anim_fail_open == 0 and $g_anim_open == 0
			animate("JointLever", angular_y, 90/$c_lever_turn_time, -90)
			$g_anim_fail_open += 1
	if $g_anim_open > 0
		$g_anim_fail_open = 0


	var $data_open = $g_open or $g_state_door_open
	var $data_locked = $g_locked or $g_state_door_locked
	output.0 ($data_open, $data_locked, $g_pushed)

	$g_pushed = 0

