#DATAPORT output "data" 0 "Fluid level"
#DATAPORT output "data" 1 "Fluid content"
#DATAPORT output "data" 2 "Fluid temperature"

#INFO text_info "capacity" "20.00 kg" "Tank capacity"
#INFO text_info "mass" "0.00 kg" "Contents mass"
#INFO text_info "temperature" "0.0 K" "Contents temperature"
#INFO text_info "composition" "" "Contents composition"

; Volume ≈ 0.02208932335 m²
const $TANK_VOLUME = 0.02
const $TANK_MASS = 10

const $TANK_CAPACITY = $TANK_VOLUME * 1000 ; for now just mass based

storage var $s_tankContents :text
storage var $s_tankContentsMass :number
storage var $s_tankTemperature :number


; add fluid to tank returns remaining fluid
function @add_fluid($fluid :text, $temperature :number) :text
	var $fluidMass = 0
	foreach $fluid ($f, $m)
		$fluidMass += $m
	
	var $fractionAdded = clamp(($TANK_CAPACITY - $s_tankContentsMass) / $fluidMass, 0, 1)

	var $addedMass = $fluidMass * $fractionAdded
	$s_tankTemperature = ($s_tankTemperature * $s_tankContentsMass + $temperature * $addedMass) / ($s_tankContentsMass + $addedMass)
	$s_tankContentsMass += $addedMass
	set_mass($TANK_MASS + $s_tankContentsMass)

	foreach $fluid ($f, $m)
		$s_tankContents.$f += $m * $fractionAdded
		$fluid.$f -= $m * $fractionAdded
	
	return $fluid

; remove fluid from tank
function @remove_fluid($maxMass :number) :text
	var $fractionRemoved = if($s_tankContentsMass != 0, clamp($maxMass / $s_tankContentsMass, 0, 1), 0)

	$s_tankContentsMass -= $s_tankContentsMass * $fractionRemoved
	set_mass($TANK_MASS + $s_tankContentsMass)

	if $fractionRemoved > 0
		var $removedComposition = ""
		foreach $s_tankContents ($f, $m)
			$removedComposition.$f = $m * $fractionRemoved
			$s_tankContents.$f -= $m * $fractionRemoved
		return $removedComposition
	else
		return ""


accept_push_fluid($port :text, $molecule :text, $inout_mass :number, $temperature :number)
	if $inout_mass == 0
		return
	var $fluid = ""
	$fluid.$molecule = $inout_mass
	$fluid.@add_fluid($temperature)
	$inout_mass = $fluid.$molecule

accept_pull_fluid($port :text, $maxMass :number, $out_composition :text, $out_temperature :number)
	$out_composition = @remove_fluid($maxMass)
	$out_temperature = $s_tankTemperature


accept_push_fluid_potential($port :text, $out_potential :number)
	$out_potential = $s_tankContentsMass < $TANK_CAPACITY

accept_pull_fluid_potential($port :text, $out_potential :number)
	$out_potential = $s_tankContentsMass > 0

tick
	set_mass($TANK_MASS + $s_tankContentsMass)
	output.0($s_tankContentsMass / $TANK_CAPACITY, $s_tankContents, $s_tankTemperature)

	; info text
	set_info("mass", text("{0.00} kg", $s_tankContentsMass))
	set_info("temperature", text("{0.0} K", $s_tankTemperature))
	
	var $composition_text = ""
	foreach $s_tankContents ($k, $v)
		if $v > 0
			$composition_text &= text("\n--- {}: {0.00} kg ({0.00}%)", $k, $v, $v / $s_tankContentsMass * 100)

	set_info("composition", $composition_text)
