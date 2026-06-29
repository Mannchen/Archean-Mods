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

const $CHILLER_MASS = 200 ; in kg
const $INTERNAL_MASS = 20 ; in archean all fluids have heat capacity of 1000 J/kg/K
const $COOLING_MAX = 300 ; K below internal temp
const $POWER_DRAW_MAX = 2000000 ; max power draw 2MW
const $PASSIVE_DRAW = 20; passive draw 20W
const $TANK_COOLANT = 50; coolant tank in l
const $TANK_FLUID = 50

storage var $s_storageInitialized :number ; if storage vars are initialized
storage var $s_on :number ; chiller on
storage var $s_targetTemperature :number ; targeted fluid output temperature
storage var $s_internalHeat :number ; internally stored heat

storage var $s_fluidContents :text ; collected fluid this tick (input)
storage var $s_fluidHeat :number ; thermal energy of fluid contents
storage var $s_coolantContents : text ; collected fluid this tick (coolant)
storage var $s_coolantHeat :number ; thermal energy of coolant

storage var $s_fluidBlocked :number ; wether there is still fluid in the chiller
storage var $s_coolantBlocked :number ; wether there is still coolant in the chiller

var $g_playSound :number ; for delay before stopping sound

; status tracking for info and display
var $status_fluidInTemp :number
var $status_fluidOutTemp :number
var $status_fluidOutMass :number
var $status_coolantInTemp :number
var $status_coolantOutTemp :number
var $status_coolantOutMass :number
var $status_powerDraw : number


; internal heat buffer
function @internal_temp() :number
	return $s_internalHeat / $INTERNAL_MASS / 1000

; heat transfer efficiency
; based on difference between fluid temperature and core temperature
function @efficiency($fluidTemp :number) :number
	return  1 / (1.5 + (clamp($fluidTemp-@internal_temp(), -$COOLING_MAX, $COOLING_MAX) / $COOLING_MAX))

accept_push_fluid($port :text, $molecule :text, $mass :number, $temperature :number)
	if $port == "fluid_coolant_in"
		; coolant
		var $pushPotential = push_fluid_potential("fluid_coolant_out")
		if $pushPotential == 0 or $s_coolantBlocked
			return
		; add coolant to tank
		var $coolantMass = 0
		foreach $s_coolantContents ($k, $v)
			$coolantMass += $v
		var $acceptedMass = min($mass * $pushPotential, $TANK_COOLANT - $coolantMass)

		$s_coolantContents.$molecule += $acceptedMass
		$s_coolantHeat += $acceptedMass * $temperature * 1000
		$coolantMass += $acceptedMass
		$mass -= $acceptedMass
		; update status
		if $coolantMass > 0
			$status_coolantInTemp = $s_coolantHeat / $coolantMass / 1000
		else
			$status_coolantInTemp = 0

	elseif $port == "fluid_target_in"
		; fluid
		var $pushPotential = push_fluid_potential("fluid_target_out")
		if $pushPotential == 0 or $s_fluidBlocked
			return
		; add fluid to tank
		var $fluidMass = 0
		foreach $s_fluidContents ($k, $v)
			$fluidMass += $v
		var $acceptedMass = min($mass * $pushPotential, $TANK_FLUID - $fluidMass)

		$s_fluidContents.$molecule += $acceptedMass
		$s_fluidHeat += $acceptedMass * $temperature * 1000
		$fluidMass += $acceptedMass
		$mass -= $acceptedMass
		; update status
		if $fluidMass > 0
			$status_fluidInTemp = $s_fluidHeat / $fluidMass / 1000
		else
			$status_fluidInTemp = 0


accept_push_fluid_potential($port :text, $out_potential :number)
	if $port == "fluid_coolant_in"
		$out_potential = !$s_coolantBlocked
	elseif $port == "fluid_target_in"
		$out_potential = !$s_fluidBlocked
	else
		$out_potential = 0


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
	var $liquidTemp = if($status_fluidOutMass > 0, @text_pad(text("{0}K", $status_fluidOutTemp), 5, "R"), " --- ")
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
	var $coolantMass = 0
	foreach $s_coolantContents ($k, $v)
		$coolantMass += $v
	var $fluidMass = 0
	foreach $s_fluidContents ($k, $v)
		$fluidMass += $v

	set_info("coolantInfo", text("{0}K -> {0}K ({} {})", $status_coolantInTemp, $status_coolantOutTemp, if($s_coolantBlocked, "blocked", @format_unit($status_coolantOutMass*1000*system_frequency, "g/s")), @format_unit($coolantMass*1000, "g")))
	set_info("fluidInfo", text("{0}K -> {0}K ({} {})", $status_fluidInTemp, $status_fluidOutTemp, if($s_fluidBlocked, "blocked", @format_unit($status_fluidOutMass*1000*system_frequency, "g/s")), @format_unit($fluidMass*1000, "g")))
	if $status_fluidInTemp > 0 or $status_fluidOutTemp > 0
		var $efficiency = @efficiency($status_fluidInTemp)
		set_info("coreInfo", text("{0}K ({0}% efficiency)", @internal_temp(), 100/$efficiency))
	else
		set_info("coreInfo", text("{0}K", @internal_temp()))
	
	set_info("powerInfo", text("{} / {} {}", @format_unit($status_powerDraw, "W"), @format_unit($POWER_DRAW_MAX, "W"), if($s_on, "", "(off)")))


array $a_soundPitch :number
tick
	var $powerReceived = 0
	var $prevHeat = $s_coolantHeat

	$status_coolantOutMass = 0
	$status_fluidOutMass = 0

	; cool
	var $fluidMass = 0
	foreach $s_fluidContents ($k, $v)
		$fluidMass += $v
	if $fluidMass > 0
		var $fluidInTemp = $s_fluidHeat / 1000 / $fluidMass
		var $fluidOutTemp = $fluidInTemp
		if $s_on
			; get theoretical output temperature 
			var $coolingTemp = $fluidInTemp - max($s_targetTemperature, @internal_temp()-$COOLING_MAX)
			if $coolingTemp > 0
			; get power required
			var $efficiency = @efficiency($fluidInTemp)
			var $powerRequired = clamp(1000 * $fluidMass * $coolingTemp * $efficiency * system_frequency, 0, $POWER_DRAW_MAX + $PASSIVE_DRAW)
			; pull power
			$powerReceived = clamp(pull_power("hv", 300, $powerRequired + $PASSIVE_DRAW), 0, $POWER_DRAW_MAX + $PASSIVE_DRAW)
			var $powerCooling = max(0, $powerReceived - $PASSIVE_DRAW)

			if $powerRequired
				$fluidOutTemp = $fluidInTemp - $coolingTemp * $powerCooling / $powerRequired

			$s_internalHeat += ($powerCooling + $powerCooling / $efficiency) / system_frequency
			$s_fluidHeat -= $powerCooling / $efficiency / system_frequency

		else
			$powerReceived = pull_power("hv", 300, $PASSIVE_DRAW)

		; output fluid
		foreach $s_fluidContents ($k, $v)
			var $acceptedMass = push_fluid("fluid_target_out", $k, $v:number, $fluidOutTemp)
			$s_fluidContents.$k -= $acceptedMass
			$fluidMass -= $acceptedMass
			$status_fluidOutMass += $acceptedMass
			$s_fluidHeat -= $acceptedMass * $fluidOutTemp * 1000
		$status_fluidOutTemp = $fluidOutTemp

		if $fluidMass > $TANK_FLUID
			$s_fluidBlocked = 1
		if $fluidMass < 0.000001
			$s_fluidBlocked = 0
			$s_fluidHeat = 0
			$s_fluidContents = ""

	else
		$s_fluidBlocked = 0
		$s_fluidHeat = 0
		$s_fluidContents = ""
		$powerReceived = pull_power("hv", 300, $PASSIVE_DRAW)

	var $coolantMass = 0
	foreach $s_coolantContents ($k, $v)
		$coolantMass += $v

	if $coolantMass > 0
		; heat coolant
		var $coolantOutTemp = ($s_coolantHeat + $s_internalHeat) / 1000 / ($coolantMass + $INTERNAL_MASS)
		$s_internalHeat = $INTERNAL_MASS * $coolantOutTemp * 1000
		$status_coolantOutTemp = $coolantOutTemp

		;output coolant
		foreach $s_coolantContents ($k, $v)
			var $acceptedMass = push_fluid("fluid_coolant_out", $k, $v:number, $coolantOutTemp)
			$s_coolantContents.$k -= $acceptedMass
			$coolantMass -= $acceptedMass
			$status_coolantOutMass += $acceptedMass
			$s_coolantHeat -= $acceptedMass * $coolantOutTemp * 1000
		$status_coolantOutTemp = $coolantOutTemp

		if $coolantMass > $TANK_COOLANT
			$s_coolantBlocked = 1
		if $coolantMass < 0.000001
			$s_coolantBlocked = 0
			$s_coolantHeat = 0
			$s_coolantContents = ""
	
	else
		$s_coolantBlocked = 0
		$s_coolantHeat = 0
		$s_coolantContents = ""
	
	; mass
	set_mass($CHILLER_MASS + $fluidMass + $coolantMass)

	; ui
	if $status_powerDraw >= $PASSIVE_DRAW
		@draw_ui()
	else
		$screen.blank(black)
		$g_playSound = 0

	; info menu
	$status_powerDraw = $powerReceived
	@info_status()

	; smoothing for sound volume&pitch based on load
	if $powerReceived > $PASSIVE_DRAW*2
		$g_playSound = 25
	else
		if $g_playSound > 0
			$g_playSound -= 1
	$a_soundPitch.append($powerReceived / $POWER_DRAW_MAX)
	if size($a_soundPitch) > 25
		$a_soundPitch.erase(0)

	; play sound
	if $g_playSound > 0
		var $freq = 50 * (1+$a_soundPitch.avg)
		var $amp = 0.50 * (1+$a_soundPitch.avg)
		play_tone("sound", triangle_wave, $freq, $amp)
	
	else
		play_tone("sound", triangle_wave, 0, 0)
	
	; dataport output
	output.0($status_fluidOutTemp, $status_coolantOutTemp)

	$status_fluidInTemp = 0
	$status_coolantInTemp = 0
	$status_fluidOutTemp = 0
	$status_coolantOutTemp = 0
