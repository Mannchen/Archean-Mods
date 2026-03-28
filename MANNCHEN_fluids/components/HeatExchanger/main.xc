; HeatExchanger

#INFO text_info "core" "" "Core"
#INFO text_info "fluid_shell" "" "Shell"
#INFO text_info "fluid_tube" "" "Tube"

const $INTERNAL_MASS = 100 ; kg


storage var $s_internalHeat :number
storage var $s_storageInitialized :number

var $status_shellInputTemp :number
var $status_shellOutputTemp :number
var $status_tubeInputTemp :number
var $status_tubeOutputTemp :number


; returns temperature of the core
function @internal_temperature() :number
	return $s_internalHeat / $INTERNAL_MASS / 1000


; returns temperature of the fluid after heat exchange
function @get_equalized_temperature($mass :number, $temperature :number) :number
	var $outputTemperature = ($mass * $temperature + $INTERNAL_MASS * @internal_temperature()) / ($mass + $INTERNAL_MASS)
	return $outputTemperature

; add / remove heat from the core
function @change_internal_heat($mass :number, $inputTemperature :number, $outputTemperature :number)
	var $fluidHeat = 1000 * $mass * ($inputTemperature - $outputTemperature)
	$s_internalHeat += $fluidHeat


; get other port
function @get_opposite_port($port :text) :text
	if $port == "fluidTop"
		return "fluidBottom"
	elseif $port == "fluidBottom"
		return "fluidTop"
	elseif $port == "fluidFront"
		return "fluidBack"
	elseif $port == "fluidBack"
		return "fluidFront"


; equalize temperature of fluid and core
accept_push_fluid($port :text, $molecule :text, $mass :number, $temperature :number)
	var $oppositePort = @get_opposite_port($port)
	var $potential = clamp(push_fluid_potential($oppositePort), 0, 1)
	var $outputTemperature = @get_equalized_temperature($mass * $potential, $temperature)
	var $acceptedMass = push_fluid($oppositePort, $molecule, $mass * $potential, $outputTemperature)
	@change_internal_heat($acceptedMass, $temperature, $outputTemperature)
	$mass -= $acceptedMass

	
	if $port == "fluidTop" or $port == "fluidBottom"
		$status_shellInputTemp = $temperature
		$status_shellOutputTemp = $outputTemperature
	elseif $port == "fluidFront" or $port == "fluidBack"
		$status_tubeInputTemp = $temperature
		$status_tubeOutputTemp = $outputTemperature

accept_pull_fluid($port :text, $maxMass :number, $out_composition :text, $out_temperature :number)
	var $oppositePort = @get_opposite_port($port)
	var $pulledFluid = pull_fluid($oppositePort, $maxMass)

	var $pulledFluid_temp = $pulledFluid.temperature
	var $pulledFluid_comp = $pulledFluid.composition
	var $pulledMass = 0
	foreach $pulledFluid_comp ($f, $m)
		$pulledMass += $m
	
	$out_temperature = @get_equalized_temperature($pulledMass, $pulledFluid_temp)
	$out_composition = $pulledFluid.composition
	@change_internal_heat($pulledMass, $pulledFluid_temp, $out_temperature)

	if $port == "fluidTop" or $port == "fluidBottom"
		$status_shellInputTemp = $pulledFluid_temp
		$status_shellOutputTemp = $out_temperature
	elseif $port == "fluidFront" or $port == "fluidBack"
		$status_tubeInputTemp = $pulledFluid_temp
		$status_tubeOutputTemp = $out_temperature


init
	if $s_storageInitialized == 0
		$s_storageInitialized = 1
		$s_internalHeat = 1000 * 300 * $INTERNAL_MASS ; start at 300K


tick
	set_info("core", text("{}K", @internal_temperature()))
	if $status_shellInputTemp > 0
		set_info("fluid_shell", text("{}K -> {}K", $status_shellInputTemp, $status_shellOutputTemp))
	else
		set_info("fluid_shell", "---")
	
	if $status_tubeInputTemp > 0
		set_info("fluid_tube", text("{}K -> {}K", $status_tubeInputTemp, $status_tubeOutputTemp))
	else
		set_info("fluid_tube", "---")

	; reset per tick variables
	$status_shellInputTemp = 0
	$status_shellOutputTemp = 0
	$status_tubeInputTemp = 0
	$status_tubeOutputTemp = 0
