#DATAPORT input "data" 0 "Enable (0/1)"
#DATAPORT input "data" 1 "Output Fluid (.molecule{kg}...)"
#DATAPORT input "data" 2 "Output FLuid temperature (K)"
#DATAPORT input "data" 3 "Accept Fluid (maxMass)"
#DATAPORT input "data" 4 "Push Fluid (0/1)"
#DATAPORT input "data" 5 "Pull Fluid (0/1)"


#DATAPORT output "data" 0 "Fluid sent (k-v)"
#DATAPORT output "data" 1 "Fluid received (k-v)"

#INFO checkbox "enable" 1 "Enable"
#INFO checkbox "enable_data" 0 "Allow dataport configuration"
#INFO text "send_fluid" "" "Output Fluid (.molecule{kg}...)"
#INFO checkbox "push" 1 "Push Fluid"
#INFO text "temp" "293.15" "Fluid Temperature"
#INFO text "accept_fluid" "0" "Accept Fluid (kg/s)"
#INFO checkbox "pull" 0 "Pull Fluid"
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
var $g_send_fluid :text
var $info_send_fluid :text
var $g_temp :number
var $info_temp :text
var $g_accept_fluid :number
var $info_accept_fluid :text
var $g_pull :number
var $info_pull :number
var $g_push :number
var $info_push :number

array $g_send_fluid_acc :number
array $g_pull_fluid_acc :number

var $g_accepted_this_frame :text
var $g_total_accepted :number
var $g_sent_this_frame :text

var $delta :number

init
	$delta = 1/system_frequency


input.0 ($enable :text, $send_fluid :text, $fluid_temp :text, $accept_fluid :text, $push_fluid :text, $pull_fluid :text)
	if get_info("enable_data") == 0
		return

	if $enable != ""
		$g_enable = $enable :number
	if $send_fluid != ""
		$g_send_fluid = upper($send_fluid)
	if $fluid_temp != ""
		$g_temp = $fluid_temp :number
	if $accept_fluid != ""
		$g_accept_fluid = $accept_fluid :number
	if $push_fluid != ""
		$g_push = $push_fluid :number
	if $pull_fluid != ""
		$g_pull = $pull_fluid :number

	$enable = ""
	$send_fluid = ""
	$fluid_temp = ""
	$accept_fluid = ""
	$push_fluid = ""
	$pull_fluid = ""


tick
	; update info when changed
	var $new_info_enable = get_info("enable")
	if $new_info_enable != $info_enable
		$g_enable = $new_info_enable
	$info_enable = $new_info_enable

	var $new_info_send_fluid = upper(get_info_text("send_fluid"))
	if $new_info_send_fluid != $info_send_fluid
		$g_send_fluid = $new_info_send_fluid
	$info_send_fluid = $new_info_send_fluid

	var $new_info_push = get_info("push")
	if $new_info_push != $info_push
		$g_push = $new_info_push
	$info_push = $new_info_push

	var $new_info_temp = get_info_text("temp")
	if $new_info_temp != $info_temp
		if isnumeric($new_info_temp)
			$g_temp = $new_info_temp :number
		else
			set_info("temp", $info_temp)
			$new_info_temp = $info_temp
	$info_temp = $new_info_temp

	var $new_info_accept_fluid = upper(get_info_text("accept_fluid"))
	if $new_info_accept_fluid != $info_accept_fluid
		if isnumeric($new_info_accept_fluid)
			$g_accept_fluid = $new_info_accept_fluid
		else
			set_info("accept_fluid", $info_accept_fluid)
			$new_info_accept_fluid = $info_accept_fluid
	$info_accept_fluid = $new_info_accept_fluid

	var $new_info_pull = get_info("pull")
	if $new_info_pull != $info_pull
		$g_pull = $new_info_pull
	$info_pull = $new_info_pull


	; V menu stats
	var $total_sent = 0
	foreach $g_sent_this_frame ($molecule, $mass)
		$total_sent += $mass
	$g_send_fluid_acc.append($total_sent)
	$g_pull_fluid_acc.append($g_total_accepted)
	var $f = 1/$delta
	if $g_send_fluid_acc.size >= $f
		set_info("stats", text("Fluid output: {} Fluid input: {}", @format_unit($g_send_fluid_acc.avg*$f*1000, "g"), @format_unit($g_pull_fluid_acc.avg*$f*1000, "g")))
		$g_pull_fluid_acc.clear()
		$g_send_fluid_acc.clear()

	output.0($g_sent_this_frame, $g_accepted_this_frame)
	$g_sent_this_frame = ""
	$g_accepted_this_frame = ""
	$g_total_accepted = 0


	if $g_enable
		if $g_push
			foreach $g_send_fluid ($molecule, $mass)
				var $sent = push_fluid("fluid", $molecule, max(0, $mass*$delta - $g_sent_this_frame.$molecule), $g_temp)
				$g_sent_this_frame.$molecule += $sent
				$total_sent += $sent
		
		if $g_pull
			var $pulled = pull_fluid("fluid", max(0, $g_accept_fluid*$delta-$g_total_accepted))
			$pulled = $pulled.composition
			foreach $pulled ($k, $v)
				if $v == 0
					continue
				var $already = $g_accepted_this_frame.$k
				var $a_mass = $already.m
				var $t_mass = $a_mass + $v
				$already.m += $t_mass
				$already.t = ($a_mass/$t_mass) * $already.t + ($v/$t_mass) * $pulled.temperature
				$g_accepted_this_frame.$k = $already
				$g_total_accepted += $v


accept_push_fluid ($port :text, $molecule :text, $mass :number, $temperature :number)
	if $g_enable and $g_accept_fluid > 0
		var $accepted = min($mass, $g_accept_fluid*$delta - $g_total_accepted)

		var $already = $g_accepted_this_frame.$molecule
		var $a_mass = $already.m
		var $t_mass = $a_mass + $accepted
		$already.m += $t_mass
		$already.t = ($a_mass/$t_mass) * $already.t + ($accepted/$t_mass) * $temperature
		$g_accepted_this_frame.$molecule = $already
		$g_total_accepted += $accepted

		$mass -= $accepted

accept_push_fluid_potential ($port :text, $potential :number)
	$potential = $g_enable and $g_accept_fluid > 0

accept_pull_fluid ($port :text, $maxMass :number, $compositionOut :text, $temperature_out :number)
	if $g_enable
		var $remaining = ""
		var $remaining_total = 0
		foreach $g_send_fluid ($molecule, $mass)
			$remaining.$molecule = $mass*$delta - $g_sent_this_frame.$molecule
			$remaining_total += $remaining.$molecule
		var $accepted = min($maxMass, $remaining_total)
		if $accepted > 0
			var $ratio = $accepted / $remaining_total
			$temperature_out = $g_temp
			foreach $remaining ($molecule, $mass)
				$compositionOut.$molecule = $mass * $ratio
				$g_sent_this_frame.$molecule += $mass * $ratio
			$compositionOut = upper($compositionOut)

accept_pull_fluid_potential ($port :text, $potential :number)
	$potential = $g_enable and $g_send_fluid != ""

