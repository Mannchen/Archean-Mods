include "basics_text.xc" 

; Screen 4:1
#SCREEN "screen" 96 24

#DATAPORT input "data" 0 "On/Off"
#DATAPORT input "data" 1 "Target temperature (K)"
#DATAPORT output "data" 0 "Fluid output temperature (K)"
#DATAPORT output "data" 1 "Coolant temperature (K)"

#INFO text_info "fluidInfo" "---" "Fluid"
#INFO text_info "coolantInfo" "---" "Coolant"
#INFO text_info "coreInfo" "---" "Core temp"
#INFO text_info "powerInfo" "0W / 2 MW" "Power Used"

var $screen = screen("screen")

const $INTERNAL_MASS = 20 ; in archean all fluids have heat capacity of 1000 J/kg/K
const $COOLING_MAX = 150 ; K below internal temp
const $POWER_DRAW_MAX = 2000000 ; max power draw 2MW


storage var $s_on :number ; chiller on
storage var $s_targetTemperature :number ; targeted fluid output temperature
storage var $s_storageInitialized :number ; if storage vars are initialized
storage var $s_internalHeat :number ; internally stored heat
storage var $s_powerDeficit :number ; 

var $g_tickPowerDraw :number ; power pulled this tick
var $g_playSound :number ; for delay before stopping sound

; status tracking for info and display
var $status_fluidInTemp :number
var $status_fluidOutTemp :number
var $status_coolantInTemp :number
var $status_coolantOutTemp :number



; internal heat buffer
function @internal_temp() :number
	return $s_internalHeat / $INTERNAL_MASS / 1000

; heat transfer efficiency
; based on difference between fluid temperature and core temperature
function @efficiency($fluidTemp :number) :number
	return  1 / (1.5 + (clamp($fluidTemp-@internal_temp(), -$COOLING_MAX, $COOLING_MAX) / $COOLING_MAX))

; get coolad output temperature of fluid
; also draws power for cooling operation
function @calc_output_temp_fluid($mass :number, $inputTemp :number) :number
	if !$s_on or $s_powerDeficit > 0 or $mass <= 0 ; if not on do nothing
		return $inputTemp
	; get theoretical output temperature 
	var $coolingTemp = $inputTemp - max($s_targetTemperature, @internal_temp()-$COOLING_MAX)
	if $coolingTemp <= 0 or $mass == 0
		return $inputTemp ; can't cool fluid
	; get power required
	var $efficiency = @efficiency($inputTemp)
	var $powerRequired = min(1000 * $mass * $coolingTemp * $efficiency * system_frequency, ($POWER_DRAW_MAX - $g_tickPowerDraw))
	; pull power
	$g_tickPowerDraw += $powerRequired

	return $inputTemp - $coolingTemp

; add heat removed from fluid + waste heat form power to internal buffer
function @transfer_heat_fluid($mass :number, $inputTemp :number, $outputTemp :number)
	var $coolingTemp = $inputTemp - $outputTemp
	var $efficiency = @efficiency($inputTemp)
	var $powerRequired = 1000 * $mass * $coolingTemp * $efficiency * system_frequency

	$s_internalHeat += ($powerRequired + $powerRequired / $efficiency) / system_frequency


; get output temperature for coolant
; brings coolant and core to same temperature
function @calc_output_temp_coolant($mass :number, $inputTemp :number) :number
	if $mass <= 0
		return $inputTemp ; no coolant
	
	var $coolantHeat = 1000 * $mass * $inputTemp
	var $totalHeat = $coolantHeat + $s_internalHeat
	var $totalMass = $mass + $INTERNAL_MASS

	var $newCoolantHeat = $totalHeat * ($mass / $totalMass)
	var $newCoolantTemp = $newCoolantHeat / 1000 / $mass

	return $newCoolantTemp

; remove heat removed by coolant from core
function @transfer_heat_coolant($mass :number, $inputTemp :number, $outputTemp :number)
	$s_internalHeat -= 1000 * $mass * ($outputTemp - $inputTemp)


; get opposite port to $port
function @get_opposite_port($port :text) :text
	if $port == "fluid_coolant_a"
		return "fluid_coolant_b"
	elseif $port == "fluid_coolant_b"
		return "fluid_coolant_a"
	elseif $port == "fluid_target_a"
		return "fluid_target_b"
	elseif $port == "fluid_target_b"
		return "fluid_target_a"


accept_push_fluid($port :text, $molecule :text, $mass :number, $temperature :number)
	; get potential of opposite port
	var $oppositePort = @get_opposite_port($port)
	var $pushPotential = push_fluid_potential($oppositePort)

	if $port == "fluid_coolant_a" or $port == "fluid_coolant_b"
		; coolant
		var $outputTemp = @calc_output_temp_coolant($mass * $pushPotential, $temperature)
		var $acceptedMass = push_fluid($oppositePort, $molecule, $mass, $outputTemp)
		@transfer_heat_coolant($acceptedMass, $temperature, $outputTemp)
		$mass -= $acceptedMass
		if $acceptedMass > 0
			$status_coolantInTemp = $temperature
			$status_coolantOutTemp = $outputTemp

	else
		; fluid
		var $outputTemp = @calc_output_temp_fluid($mass * $pushPotential, $temperature)
		var $acceptedMass = push_fluid($oppositePort, $molecule, $mass, $outputTemp)
		if $acceptedMass > $mass * $pushPotential
			; should not happen
			print("pushed more fluid then expected!")
			@calc_output_temp_fluid($acceptedMass - $mass * $pushPotential, $temperature) ; try to consume more power
		@transfer_heat_fluid($acceptedMass, $temperature, $outputTemp)
		$mass -= $acceptedMass
		if $acceptedMass > 0
			$status_fluidInTemp = $temperature
			$status_fluidOutTemp = $outputTemp


accept_pull_fluid($port :text, $maxMass :number, $out_composition :text, $out_temperature :number)
	; pull fluid from opposite port
	var $oppositePort = @get_opposite_port($port)
	var $pulled = pull_fluid($oppositePort, $maxMass)
	var $pulled_comp = $pulled.composition
	var $pulled_temp = $pulled.temperature
	var $pulledMass = 0
	foreach $pulled_comp ($k, $v)
		$pulledMass += $v

	if $port == "fluid_coolant_a" or $port == "fluid_coolant_b"
		; coolant
		$out_temperature = @calc_output_temp_coolant($pulledMass, $pulled_temp)
		$out_composition = $pulled_comp
		@transfer_heat_coolant($pulledMass, $pulled_temp, $out_temperature)
		if $pulledMass > 0
			$status_coolantInTemp = $pulled_temp
			$status_coolantOutTemp = $out_temperature

	else
		; fluid
		$out_temperature = @calc_output_temp_fluid($pulledMass, $pulled_temp)
		$out_composition = $pulled_comp
		@transfer_heat_fluid($pulledMass, $pulled_temp, $out_temperature)
		if $pulledMass > 0
			$status_fluidInTemp = $pulled_temp
			$status_fluidOutTemp = $out_temperature

; forward potential from opposite port
accept_pull_fluid_potential($port :text, $out_potential :number)
	$out_potential = pull_fluid_potential(@get_opposite_port($port))

accept_push_fluid_potential($port :text, $out_potential :number)
	$out_potential = push_fluid_potential(@get_opposite_port($port))

; data inputs
input.0 ($on :number, $target :number)
	if $target
		$s_targetTemperature = max(0, $target)
		$target = 0
	$s_on = $on


init
	; init storage vars
	if !$s_storageInitialized
		$s_storageInitialized = 1
		$s_targetTemperature = 300
		$s_internalHeat = 1000 * 300 * $INTERNAL_MASS


; color gradient blue -> green -> red
function @color($temp :number) :number
	var $r = 0.5 + clamp($temp/(2*$COOLING_MAX), 0, 0.5)
	var $g = 0.5 + clamp(($COOLING_MAX-abs($temp))/(2*$COOLING_MAX), 0, 0.5)
	var $b = 0.5 + clamp(-$temp/(2*$COOLING_MAX), 0, 0.5)
	return color($r*255, $g*255, $b*255)


; screen UI
var $g_screen_clicked :number
function @draw_ui()
	$screen.blank(black)
	var $liquidTemp = if($status_fluidOutTemp > 0, @text_pad(text("{0}K", $status_fluidOutTemp), 5, "R"), " --- ")
	$screen.write(12, 2, @color(($status_fluidOutTemp - $s_targetTemperature)*10), $liquidTemp)
	$screen.write(54, 2, @color(@internal_temp()-$s_targetTemperature), @text_pad(text("{0}K", @internal_temp()), 5, "R"))
	$screen.write(33, 14, white, @text_pad(text("{0}K", $s_targetTemperature), 5, "R"))
	var $clicked = 0
	if $screen.button_rect(0, 12, 14, 24, gray, gray)
		$clicked = 1
		if !$g_screen_clicked
			$s_targetTemperature -= 10
	if $screen.button_rect(15, 12, 29, 24, gray, gray)
		$clicked = 1
		if !$g_screen_clicked
			$s_targetTemperature -= 1
	if $screen.button_rect(67, 12, 81, 24, gray, gray)
		$clicked = 1
		if !$g_screen_clicked
			$s_targetTemperature += 1
	if $screen.button_rect(82, 12, 96, 24, gray, gray)
		$clicked = 1
		if !$g_screen_clicked
			$s_targetTemperature += 10
	$screen.write(1, 14, white, "<<")
	$screen.write(19, 14, white, "<")
	$screen.write(71, 14, white, ">")
	$screen.write(83, 14, white, ">>")

	if $s_targetTemperature < 0
		$s_targetTemperature = 0

; info menu data
function @info_status()
	if $status_coolantOutTemp > 0
		set_info("coolantInfo", text("{0}K -> {0}K", $status_coolantInTemp, $status_coolantOutTemp))
	else
		set_info("coolantInfo", "---")
	if $status_fluidOutTemp > 0
		set_info("fluidInfo", text("{0}K -> {0}K", $status_fluidInTemp, $status_fluidOutTemp))
	else
		set_info("fluidInfo", "---")
	if $status_fluidInTemp > 0
		var $efficiency = @efficiency($status_fluidInTemp)
		set_info("coreInfo", text("{0}K ({0}% efficiency)", @internal_temp(), 100/$efficiency))
	else
		set_info("coreInfo", text("{0}K", @internal_temp()))
	
	set_info("powerInfo", text("{} / {}", @format_unit($g_tickPowerDraw, "W"), @format_unit($POWER_DRAW_MAX, "W")))


array $a_soundPitch :number
tick
	; passive power draw
	if $s_powerDeficit <= 0
		$g_tickPowerDraw += 20

	; draw power
	var $power_Received = pull_power("hv", 300, $g_tickPowerDraw + $s_powerDeficit)
	$s_powerDeficit += $g_tickPowerDraw - $power_Received
	$g_tickPowerDraw = $power_Received

	; show ui when chiller has power
	if $s_powerDeficit <= 0
		@draw_ui()
	else
		$screen.blank(black)
		$g_playSound = 0
	; info menu
	@info_status()

	; smoothing for sound volume&pitch based on load
	if $g_tickPowerDraw > 40
		if $g_playSound < 25
			$g_playSound += 10
	else
		if $g_playSound > 0
			$g_playSound -= 1
	$a_soundPitch.append($g_tickPowerDraw/$POWER_DRAW_MAX)
	if size($a_soundPitch) > 25
		$a_soundPitch.erase(0)

	; play sound
	if $g_playSound
		var $freq = 50 * (1+$a_soundPitch.avg)
		var $amp = 0.50 * (1+$a_soundPitch.avg)
		play_tone("sound", triangle_wave, $freq, $amp)
	
	else
		play_tone("sound", triangle_wave, 0, 0)
	
	; dataport output
	output.0($status_fluidOutTemp, $status_coolantOutTemp)

	; reset per tick values
	$g_tickPowerDraw = 0
	$status_coolantInTemp = 0
	$status_coolantOutTemp = 0
	$status_fluidInTemp = 0
	$status_fluidOutTemp = 0

