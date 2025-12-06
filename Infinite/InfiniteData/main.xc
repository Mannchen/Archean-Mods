#DATAPORT "data.0" input.0 "Enable (0|1)"
#DATAPORT "data.0" input.1 "Send Data (.c0{data}.c1{data}....c19{data})"
#DATAPORT "data.0" input.2 "Only output changes (0|1)"
#DATAPORT "data.0" output.0 "Received Data (.cX{data}...)"

#INFO checkbox "enable" 1 "Enable"
#INFO checkbox "enable_data" 0 "Allow dataport configuration"
#INFO checkbox "changes_only" 0 "Only receive changes"

#INFO text "ch_0" "" " 0"
#INFO text "ch_1" "" " 1"
#INFO text "ch_2" "" " 2"
#INFO text "ch_3" "" " 3"
#INFO text "ch_4" "" " 4"
#INFO text "ch_5" "" " 5"
#INFO text "ch_6" "" " 6"
#INFO text "ch_7" "" " 7"
#INFO text "ch_8" "" " 8"
#INFO text "ch_9" "" " 9"
#INFO text "ch_10" "" "10"
#INFO text "ch_11" "" "11"
#INFO text "ch_12" "" "12"
#INFO text "ch_13" "" "13"
#INFO text "ch_14" "" "14"
#INFO text "ch_15" "" "15"
#INFO text "ch_16" "" "16"
#INFO text "ch_17" "" "17"
#INFO text "ch_18" "" "18"
#INFO text "ch_19" "" "19"


array $g_outputs :text
array $g_prev_outputs :text

var $g_incoming_signals :text

var $g_enable :number
var $info_enable :number
var $g_changes_only :number
var $info_changes_only :number

var $info_ch_0 :text
var $info_ch_1 :text
var $info_ch_2 :text
var $info_ch_3 :text
var $info_ch_4 :text
var $info_ch_5 :text
var $info_ch_6 :text
var $info_ch_7 :text
var $info_ch_8 :text
var $info_ch_9 :text
var $info_ch_10 :text
var $info_ch_11 :text
var $info_ch_12 :text
var $info_ch_13 :text
var $info_ch_14 :text
var $info_ch_15 :text
var $info_ch_16 :text
var $info_ch_17 :text
var $info_ch_18 :text
var $info_ch_19 :text


;
; output
;

init
	$g_outputs.fill(20, "")


tick
	var $new_info_enable = get_info("enable")
	if $new_info_enable != $info_enable
		$g_enable = $new_info_enable
	$info_enable = $new_info_enable

	var $new_info_changes_only = get_info("changes_only")
	if $new_info_changes_only != $info_changes_only
		$g_changes_only = $new_info_changes_only
	$info_changes_only = $new_info_changes_only

	var $new_info_ch_0 = get_info_text("ch_0")
	if $new_info_ch_0 != $info_ch_0
		$g_outputs.0 = $new_info_ch_0
	$info_ch_0 = $new_info_ch_0
	var $new_info_ch_1 = get_info_text("ch_1")
	if $new_info_ch_1 != $info_ch_1
		$g_outputs.1 = $new_info_ch_1
	$info_ch_1 = $new_info_ch_1
	var $new_info_ch_2 = get_info_text("ch_2")
	if $new_info_ch_2 != $info_ch_2
		$g_outputs.2 = $new_info_ch_2
	$info_ch_2 = $new_info_ch_2
	var $new_info_ch_3 = get_info_text("ch_3")
	if $new_info_ch_3 != $info_ch_3
		$g_outputs.3 = $new_info_ch_3
	$info_ch_3 = $new_info_ch_3
	var $new_info_ch_4 = get_info_text("ch_4")
	if $new_info_ch_4 != $info_ch_4
		$g_outputs.4 = $new_info_ch_4
	$info_ch_4 = $new_info_ch_4
	var $new_info_ch_5 = get_info_text("ch_5")
	if $new_info_ch_5 != $info_ch_5
		$g_outputs.5 = $new_info_ch_5
	$info_ch_5 = $new_info_ch_5
	var $new_info_ch_6 = get_info_text("ch_6")
	if $new_info_ch_6 != $info_ch_6
		$g_outputs.6 = $new_info_ch_6
	$info_ch_6 = $new_info_ch_6
	var $new_info_ch_7 = get_info_text("ch_7")
	if $new_info_ch_7 != $info_ch_7
		$g_outputs.7 = $new_info_ch_7
	$info_ch_7 = $new_info_ch_7
	var $new_info_ch_8 = get_info_text("ch_8")
	if $new_info_ch_8 != $info_ch_8
		$g_outputs.8 = $new_info_ch_8
	$info_ch_8 = $new_info_ch_8
	var $new_info_ch_9 = get_info_text("ch_9")
	if $new_info_ch_9 != $info_ch_9
		$g_outputs.9 = $new_info_ch_9
	$info_ch_9 = $new_info_ch_9
	var $new_info_ch_10 = get_info_text("ch_10")
	if $new_info_ch_10 != $info_ch_10
		$g_outputs.10 = $new_info_ch_10
	$info_ch_10 = $new_info_ch_10
	var $new_info_ch_11 = get_info_text("ch_11")
	if $new_info_ch_11 != $info_ch_11
		$g_outputs.11 = $new_info_ch_11
	$info_ch_11 = $new_info_ch_11
	var $new_info_ch_12 = get_info_text("ch_12")
	if $new_info_ch_12 != $info_ch_12
		$g_outputs.12 = $new_info_ch_12
	$info_ch_12 = $new_info_ch_12
	var $new_info_ch_13 = get_info_text("ch_13")
	if $new_info_ch_13 != $info_ch_13
		$g_outputs.13 = $new_info_ch_13
	$info_ch_13 = $new_info_ch_13
	var $new_info_ch_14 = get_info_text("ch_14")
	if $new_info_ch_14 != $info_ch_14
		$g_outputs.14 = $new_info_ch_14
	$info_ch_14 = $new_info_ch_14
	var $new_info_ch_15 = get_info_text("ch_15")
	if $new_info_ch_15 != $info_ch_15
		$g_outputs.15 = $new_info_ch_15
	$info_ch_15 = $new_info_ch_15
	var $new_info_ch_16 = get_info_text("ch_16")
	if $new_info_ch_16 != $info_ch_16
		$g_outputs.16 = $new_info_ch_16
	$info_ch_16 = $new_info_ch_16
	var $new_info_ch_17 = get_info_text("ch_17")
	if $new_info_ch_17 != $info_ch_17
		$g_outputs.17 = $new_info_ch_17
	$info_ch_17 = $new_info_ch_17
	var $new_info_ch_18 = get_info_text("ch_18")
	if $new_info_ch_18 != $info_ch_18
		$g_outputs.18 = $new_info_ch_18
	$info_ch_18 = $new_info_ch_18
	var $new_info_ch_19 = get_info_text("ch_19")
	if $new_info_ch_19 != $info_ch_19
		$g_outputs.19 = $new_info_ch_19
	$info_ch_19 = $new_info_ch_19

	if $g_enable 
		output.1($g_outputs.0, $g_outputs.1, $g_outputs.2, $g_outputs.3, $g_outputs.4, $g_outputs.5, $g_outputs.6, $g_outputs.7, $g_outputs.8, $g_outputs.9, $g_outputs.10, $g_outputs.11, $g_outputs.12, $g_outputs.13, $g_outputs.14, $g_outputs.15, $g_outputs.16, $g_outputs.17, $g_outputs.18, $g_outputs.19)

	var $incoming = ""
	foreach $g_incoming_signals ($k, $v)
		if $v != ""
			$incoming.$k = $v
	output.0($incoming)
	$g_incoming_signals = ""

;
; input
;

var $prev_ch_0 :text
var $prev_ch_1 :text
var $prev_ch_2 :text
var $prev_ch_3 :text
var $prev_ch_4 :text
var $prev_ch_5 :text
var $prev_ch_6 :text
var $prev_ch_7 :text
var $prev_ch_8 :text
var $prev_ch_9 :text
var $prev_ch_10 :text
var $prev_ch_11 :text
var $prev_ch_12 :text
var $prev_ch_13 :text
var $prev_ch_14 :text
var $prev_ch_15 :text
var $prev_ch_16 :text
var $prev_ch_17 :text
var $prev_ch_18 :text
var $prev_ch_19 :text



input.0 ($enable :text, $send_data :text, $changes_only :text)
	if get_info("enable_data") == 0
		return

	if $enable != ""
		$g_enable = $enable != 0

	if $send_data != ""
		foreach $send_data ($k,$v)
			if $k.0 != "c"
				continue
			var $ch = substring($k, 1, size($k)-1)
			if !isnumeric($ch)
				continue
			var $n_ch = $ch :number
			if $n_ch > 19 or $n_ch < 0
				continue
			$g_outputs.$n_ch = $v

	if $changes_only != ""
		$g_changes_only = $changes_only != 0
	
	$enable = ""
	$send_data = ""
	$changes_only = ""


input.1 ( $ch_0 :text, $ch_1 :text, $ch_2 :text, $ch_3 :text, $ch_4 :text, $ch_5 :text, $ch_6 :text, $ch_7 :text, $ch_8 :text, $ch_9 :text, $ch_10 :text, $ch_11 :text, $ch_12 :text, $ch_13 :text, $ch_14 :text, $ch_15 :text, $ch_16 :text, $ch_17 :text, $ch_18 :text, $ch_19 :text)
	if !$g_enable
		return

	var $all_signals = !$g_changes_only

	if $all_signals or $prev_ch_0 != $ch_0
		$g_incoming_signals.c0 = $ch_0
	if $all_signals or $prev_ch_1 != $ch_1
		$g_incoming_signals.c1 = $ch_1
	if $all_signals or $prev_ch_2 != $ch_2
		$g_incoming_signals.c2 = $ch_2
	if $all_signals or $prev_ch_3 != $ch_3
		$g_incoming_signals.c3 = $ch_3
	if $all_signals or $prev_ch_4 != $ch_4
		$g_incoming_signals.c4 = $ch_4
	if $all_signals or $prev_ch_5 != $ch_5
		$g_incoming_signals.c5 = $ch_5
	if $all_signals or $prev_ch_6 != $ch_6
		$g_incoming_signals.c6 = $ch_6
	if $all_signals or $prev_ch_7 != $ch_7
		$g_incoming_signals.c7 = $ch_7
	if $all_signals or $prev_ch_8 != $ch_8
		$g_incoming_signals.c8 = $ch_8
	if $all_signals or $prev_ch_9 != $ch_9
		$g_incoming_signals.c9 = $ch_9
	if $all_signals or $prev_ch_10 != $ch_10
		$g_incoming_signals.c10 = $ch_10
	if $all_signals or $prev_ch_11 != $ch_11
		$g_incoming_signals.c11 = $ch_11
	if $all_signals or $prev_ch_12 != $ch_12
		$g_incoming_signals.c12 = $ch_12
	if $all_signals or $prev_ch_13 != $ch_13
		$g_incoming_signals.c13 = $ch_13
	if $all_signals or $prev_ch_14 != $ch_14
		$g_incoming_signals.c14 = $ch_14
	if $all_signals or $prev_ch_15 != $ch_15
		$g_incoming_signals.c15 = $ch_15
	if $all_signals or $prev_ch_16 != $ch_16
		$g_incoming_signals.c16 = $ch_16
	if $all_signals or $prev_ch_17 != $ch_17
		$g_incoming_signals.c17 = $ch_17
	if $all_signals or $prev_ch_18 != $ch_18
		$g_incoming_signals.c18 = $ch_18
	if $all_signals or $prev_ch_19 != $ch_19
		$g_incoming_signals.c19 = $ch_19

	$prev_ch_0 = $ch_0
	$prev_ch_1 = $ch_1
	$prev_ch_2 = $ch_2
	$prev_ch_3 = $ch_3
	$prev_ch_4 = $ch_4
	$prev_ch_5 = $ch_5
	$prev_ch_6 = $ch_6
	$prev_ch_7 = $ch_7
	$prev_ch_8 = $ch_8
	$prev_ch_9 = $ch_9
	$prev_ch_10 = $ch_10
	$prev_ch_11 = $ch_11
	$prev_ch_12 = $ch_12
	$prev_ch_13 = $ch_13
	$prev_ch_14 = $ch_14
	$prev_ch_15 = $ch_15
	$prev_ch_16 = $ch_16
	$prev_ch_17 = $ch_17
	$prev_ch_18 = $ch_18
	$prev_ch_19 = $ch_19
