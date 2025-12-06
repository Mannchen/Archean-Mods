#DATAPORT "data" input.0 "Enable"
#DATAPORT "data" input.1 "Output Power (W)"
#DATAPORT "data" input.2 "Output Voltage"
#DATAPORT "data" input.3 "Consume Power (W)"

#DATAPORT "data" output.0 "Power sent (W)"
#DATAPORT "data" output.1 "Power consumed (W)"

#INFO checkbox "enable" 1 "Enable"
#INFO checkbox "enable_data" 0 "Allow dataport configuration"
#INFO text "send_p" "52" "Output Power (kW)"
#INFO text "send_v" "52" "Output Voltage"
#INFO text "receive_w" "0" "Consume Power (kW)"
#INFO text_info "stats" "---"



; get si prefix for base 10 exponent
function @get_si_prefix($e :number) :text
	array $units :text
	var $e3 = $e/3
	if $e >= 0
		$units.from(",k,M,G,T,P,E,Z,Y,R,Q", ",")
		if $e3 >= size($units) || $e % 3 != 0
			return text("e{}", $e)
		else
			return $units.$e3
	else 
		$e = abs($e)
		$e3 = abs($e3)
		$units.from(",m,u,n,p,f,a,z,y,r,q", ",")
		if $e == 1
			return "d"
		elseif $e == 2
			return "c"
		else
			if $e3 >= size($units) || $e % 3 != 0
				return text("e-{}", $e)
			else
				return $units.$e3


; format number with si prefix and optional unit
function @format_unit($number :number, $o_unit :text) :text
	var $exp = if($number == 0, 0, log(abs($number), 10))
	var $exp3 = floor($exp / 3)
	var $expf = floor($exp)
	var $n = 0
	var $return = ""
	if $expf == 3
		$exp3 -= 1
		$n = $number - ($number % 1)
		$return = text("{0}{}", $n, $o_unit)
	else
		var $prefix = @get_si_prefix($exp3*3)
		$n = ($number -  ($number - floor($number / pow(10, $expf-2))*pow(10, $expf-2)))  / pow(10, $exp3*3) ; ($number -  $number % pow(10, $expf-2))  / pow(10, $exp3*3) ; doing % ourselves because std::fmod is strange
		$return = text("{}{}{}", $n, $prefix, $o_unit)

	$o_unit = ""
	return $return



var $g_enable :number
var $info_enable :number
var $g_send_power :number
var $info_send_power :text
var $g_send_volts :number
var $info_send_volts :text
var $g_receive_power :number
var $info_receive_power :text
array $input_power_acc :number
array $output_power_acc :number


input.0 ($enable :text, $send_power :text, $send_volts :text, $receive_power :text)
	if get_info("enable_data") == 0
		return

	if $enable != ""
		$g_enable = $enable :number
	if $send_power != ""
		$g_send_power = $send_power :number
	if $send_volts != ""
		$g_send_volts = $send_volts :number
	if $receive_power != ""
		$g_receive_power = $receive_power :number

	$enable = ""
	$send_power = ""
	$send_volts = ""
	$receive_power = ""


tick
	; update info when changed
	var $new_info_enable = get_info("enable")
	if $new_info_enable != $info_enable
		$g_enable = $new_info_enable
	$info_enable = $new_info_enable

	var $new_info_send_power = get_info_text("send_p")
	if $new_info_send_power != $info_send_power
		if isnumeric($new_info_send_power)
			$g_send_power = $new_info_send_power * 1000
		else
			set_info("send_p", $info_send_power / 1000)
			$new_info_send_power = $info_send_power
	$info_send_power = $new_info_send_power

	var $new_info_send_volts = get_info_text("send_v")
	if $new_info_send_volts != $info_send_volts
		if isnumeric($new_info_send_volts)
			$g_send_volts = $new_info_send_volts
		else
			set_info("send_v", $info_send_volts)
			$new_info_send_volts = $info_send_volts
	$info_send_volts = $new_info_send_volts

	var $new_info_receive_power = get_info_text("receive_w")
	if $new_info_receive_power != $info_receive_power
		if isnumeric($new_info_receive_power)
			$g_receive_power = $new_info_receive_power * 1000
		else
			set_info("receive_w", $info_receive_power / 1000)
			$new_info_receive_power = $info_receive_power
	$info_receive_power = $new_info_receive_power


	; push and pull power
	var $power_pushed = 0
	if $g_enable && $g_send_power > 0 && $g_send_volts > 0
		$power_pushed = push_power("lv", $g_send_volts, $g_send_power)

	var $power_pulled = 0
	if $g_enable && $g_receive_power > 0
		$power_pulled = pull_power("lv", 0, $g_receive_power)

	output.0($power_pushed, $power_pulled)

	; V menu stats
	$input_power_acc.append($power_pulled)
	$output_power_acc.append($power_pushed)
	if $input_power_acc.size >= system_frequency
		set_info("stats", text("Power output: {} Power consumed: {}", @format_unit($output_power_acc.avg, "W"), @format_unit($input_power_acc.avg, "W")))
		$input_power_acc.clear()
		$output_power_acc.clear()

