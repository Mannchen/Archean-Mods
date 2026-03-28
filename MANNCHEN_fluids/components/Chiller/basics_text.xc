; Functions for strings / text


; return index for last occurrence of $what or -1 if not found
function @find_last($text :text, $what :text) :number
	var $last = -size($what)
	var $next = 0
	while $next != -1
		$next = find(substring($text, $last+size($what)), $what)
		if $next != -1
			$last = $next
	return max($last, -1)


; return number of lines in the text
function @count_lines($text :text) :number
	var $lines = 1
	var $newline_pos = 0
	while 1
		$newline_pos = find(substring($text, $newline_pos), "\n")
		if $newline_pos != -1
			$lines += 1
			$newline_pos += 2
		else
			break
	return $lines


; pad text to width
; $text: text
; $size: desired width
; $alignment: "L" for left, "C" for center, "R" for right
; $o_padding: padding character. must be one character default is space
function @text_pad($text :text, $size :number, $align :text, $o_padding :text) :text
	if $o_padding == ""
		$o_padding = " "
	var $text_size = size($text)
	var $return = ""
	if $text_size < $size
		var $diff = $size - $text_size
		var $s = ""
		if $align == "R"
			repeat $diff ($_)
				$s &= $o_padding
			$return = $s & $text
		elseif $align == "C"
			var $diffl = floor($diff/2)
			repeat $diffl ($_)
				$s &= $o_padding
			$s &= $text
			var $diffr = $size - $text_size - $diffl
			repeat $diffr ($_)
				$s &= $o_padding
			$return = $s
		else ;$align == "L"
			repeat $diff ($_)
				$text &= $o_padding
			$return = $text
	else
		$return = $text

	$o_padding = ""
	return $return


;
; Text -> Number
;

; return true if this text can be converted to number
; text must start with a digit or .[digit]
; xc will stop and ignore text after the number
; TODO: how does this compare to isnumeric()
function @can_to_number($n :text) :number
	array $arr_digits :text
	$arr_digits.from("0,1,2,3,4,5,6,7,8,9", ",")

	var $len = size($n)
	if $len == 0
		return 1

	repeat $len ($i)
		var $char = $n.$i
		if find($arr_digits, $char) != -1
			return 1
		elseif $char == "."
			continue
		else
			return 0
	return 0

; return true if this text is a integer number
; text must only contain digits
function @is_integer($n :text) :number
	array $arr_digits :text
	$arr_digits.from("0,1,2,3,4,5,6,7,8,9", ",")
	var $len = size($n)
	repeat $len ($i)
		var $char = $n.$i
		if find($arr_digits, $char) != -1
			continue
		else
			return 0
	return 1
	


;
; Formatting
;

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
function @format_unit($number :number, $o_unit :text, $o_suffix_len :number) :text
	var $exp = if($number == 0, 0, log(abs($number), 10))
	if $o_unit == "g" and $exp >= 6
		$o_unit = "t"
		$number /= 1000000
		$exp -= 6
	var $exp3 = floor($exp / 3)
	var $expf = floor($exp)
	var $return = ""
	if $expf == 3
		var $n = $number - ($number % 1)
		var $padding = @text_pad("", max(0, $o_suffix_len - size($o_unit)), "R")
		$return = text("{0}{}{}", $n, $padding, $o_unit)
	else
		var $prefix = @get_si_prefix($exp3*3)
		var $n = ($number -  ($number - floor($number / pow(10, $expf-2))*pow(10, $expf-2)))  / pow(10, $exp3*3) ; ($number -  $number % pow(10, $expf-2))  / pow(10, $exp3*3) ; doing % ourselves because std::fmod is strange
		var $padding = @text_pad("", max(0, $o_suffix_len - size($o_unit) - size($prefix)), "R")
		$return = text("{}{}{}{}", $n, $padding, $prefix, $o_unit)

	$o_unit = ""
	$o_suffix_len = 0
	return $return


; format time in seconds into Dd HH:mm:ss
function @format_time ($seconds :number) :text
	var $s = floor($seconds % 60)
	$seconds /= 60

	var $m = floor($seconds % 60)
	$seconds /= 60

	var $h = floor($seconds % 24)
	$seconds /= 24

	var $d = floor($seconds)

	if $d
		return text("{}d {}:{00}:{00}", $d, $h, $m, $s)
	elseif $h
		return text("{}:{00}:{00}", $h, $m, $s)
	elseif $m
		return text("{}:{00}", $m, $s)
	else
		return text("{}", $s)


