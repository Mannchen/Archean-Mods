#DATAPORT output "data" 0 "Flow (kg/tick}"
#DATAPORT output "data" 1 "Temperature (K)"
#DATAPORT output "data" 2 "Composition (k/v)"

#INFO text_info "flow" "0 kg/s" "Flow"
#INFO text_info "temp" "0 K" "Temperature"
#INFO text_info "comp" "" "Composition"


var $tick_flow :number
var $tick_totalMass :number
var $tick_temp :number
var $tick_comp :text


; add to tick statistics
function @add_fluid_molecule($mass :number, $molecule :text, $temperature :number, $direction :number)
	if $mass == 0
		return
	$tick_temp = ($tick_temp * $tick_totalMass + $temperature * $mass) / ($tick_totalMass + $mass)
	$tick_comp.$molecule += $mass * $direction
	$tick_flow += $mass * $direction
	$tick_totalMass += $mass

function @add_fluid_composition($composition :text, $temperature :number, $direction :number)
	var $mass = 0
	foreach $composition ($k, $v)
		$mass += $v
		$tick_comp.$k += $mass * $direction
	if $mass == 0
		return
	$tick_temp = ($tick_temp * $tick_totalMass + $temperature * $mass) / ($tick_totalMass + $mass)
	$tick_flow += $mass * $direction
	$tick_totalMass += $mass


accept_push_fluid($port :text, $molecule :text, $inout_mass :number, $temperature :number)
	if $port == "fluid1"
		var $accepted = push_fluid("fluid2", $molecule, $inout_mass, $temperature)
		$inout_mass -= $accepted
		@add_fluid_molecule($accepted, $molecule, $temperature, 1)
	else
		var $accepted = push_fluid("fluid1", $molecule, $inout_mass, $temperature)
		$inout_mass -= $accepted
		@add_fluid_molecule($accepted, $molecule, $temperature, -1)
	
accept_pull_fluid($port :text, $maxMass :number, $out_composition :text, $out_temperature :number)
	if $port == "fluid1"
		var $received = pull_fluid("fluid2", $maxMass)
		$out_composition = $received.composition
		$out_temperature = $received.temperature
		@add_fluid_composition($out_composition, $out_temperature, -1)
	else
		var $received = pull_fluid("fluid1", $maxMass)
		$out_composition = $received.composition
		$out_temperature = $received.temperature
		@add_fluid_composition($out_composition, $out_temperature, 1)

accept_push_fluid_potential($port :text, $out_potential :number)
	if $port == "fluid1"
		$out_potential = push_fluid_potential("fluid2")
	else
		$out_potential = push_fluid_potential("fluid1")

accept_pull_fluid_potential($port :text, $out_potential :number)
	if $port == "fluid1"
		$out_potential = pull_fluid_potential("fluid2")
	else
		$out_potential = pull_fluid_potential("fluid1")

tick
	; output stats
	output.0($tick_flow, $tick_temp, $tick_comp)

	; set info text
	set_info("flow", text("{0.00} kg/s", $tick_flow * system_frequency))
	set_info("temp", text("{0.00} K", $tick_temp))
	var $comp_text = ""
	foreach $tick_comp ($k, $v)
		$comp_text &= text("\n--- {}: {0.00} kg/s", $k, $v * system_frequency)
	set_info("comp", $comp_text)

	; reset per tick values
	$tick_flow = 0
	$tick_totalMass = 0
	$tick_temp = 0
	$tick_comp = ""
