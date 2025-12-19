
const $u_LEAPOCH = 946684800 + 86400*(31+29)
const $u_DAYS_PER_400Y = 365*400 + 97
const $u_DAYS_PER_100Y = 365*100 + 24
const $u_DAYS_PER_4Y   = 365*4   + 1



; https://git.musl-libc.org/cgit/musl/tree/src/time/__secs_to_tm.c?h=v0.9.15
; tm = ".year{}.month{}.day{}.week_day{}.year_day{}.day_seconds{}.hour{}.minute{}.second{}"
function @unix_to_datetime($unix_timestamp:number) :text
	var $days = 0
	var $secs = 0
	var $remdays = 0
	var $remsecs = 0
	var $remyears = 0
	var $qc_cycles = 0
	var $c_cycles = 0
	var $q_cycles = 0
	var $years = 0
	var $months = 0
	var $wday = 0
	var $yday = 0
	var $leap = 0
	array $days_in_month :number
	if $days_in_month.size == 0
		$days_in_month.from("31,30,31,30,31,31,30,31,30,31,31,29", ",")
	
	$secs = $unix_timestamp - $u_LEAPOCH
	$days = $secs / 86400
	$remsecs = $secs % 86400
	if $remsecs < 0
		$remsecs += 86400
		$days -= 1

	$wday = (3+$days)%7
	if $wday < 0 
		$wday += 7

	$qc_cycles = $days / $u_DAYS_PER_400Y
	$remdays = $days % $u_DAYS_PER_400Y
	if $remdays < 0 
		$remdays += $u_DAYS_PER_400Y
		$qc_cycles -= 1

	$c_cycles = $remdays / $u_DAYS_PER_100Y
	if $c_cycles == 4
		$c_cycles -= 1
	$remdays -= $c_cycles * $u_DAYS_PER_100Y

	$q_cycles = $remdays / $u_DAYS_PER_4Y
	if $q_cycles == 25
		$q_cycles -= 1
	$remdays -= $q_cycles * $u_DAYS_PER_4Y

	$remyears = $remdays / 365
	if $remyears == 4
		$remyears -= 1
	$remdays -= $remyears * 365

	$leap = !$remyears && ($q_cycles or !$c_cycles)
	$yday = $remdays + 31 + 28 + $leap
	if $yday >= 365+$leap
		$yday -= 365+$leap

	$years = $remyears + 4*$q_cycles + 100*$c_cycles + 400*$qc_cycles

	while $days_in_month.$months <= $remdays
		$remdays -= $days_in_month.$months
		$months += 1

	var $tm = ""

	if $months + 2 >= 12
		$tm.year = $years + 101
		$tm.month = $months - 10
	else
		$tm.year = $years + 100
		$tm.month = $months + 2
	
	$tm.day = $remdays + 1
	$tm.week_day = $wday
	$tm.year_day = $yday

	$tm.day_seconds = $remsecs
	$tm.hour = $remsecs / 3600
	$tm.minute = $remsecs / 60 % 60
	$tm.second = $remsecs % 60

	return $tm
